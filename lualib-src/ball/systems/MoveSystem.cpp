#include "MoveSystem.h"

namespace Chestnut {
namespace Ball {

void MoveSystem::SetPool(RefCountedPtr<EntitasPP::Pool> pool) {
	this->pool = pool;
}

void MoveSystem::FixedExecute() {

}

}
}