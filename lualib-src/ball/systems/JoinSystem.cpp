#include "JoinSystem.h"

#include <components/IndexComponent.h>
#include <components/PositionComponent.h>
#include <base/fixedptmath.h>

namespace Chestnut {
namespace Ball {

void JoinSystem::SetPool(RefCountedPtr< Chestnut::EntitasPP::Pool> pool) {
	this->_pool = pool;
}

void JoinSystem::Join(int index) {
	auto entity = _pool->CreateEntity();
	entity->Add<IndexComponent>(index);
	entity->Add<PositionComponent>(fix16_zero, fix16_zero, fix16_zero);
}

void JoinSystem::Leave(int index) {

}

}
}